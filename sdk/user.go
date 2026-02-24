package sdk

import (
	"fmt"
	"net/url"
)

// GetUserInfo 获取用户信息
// 返回标准响应结构
func (qc *QuarkClient) GetUserInfo() (*StandardResponse, error) {
	// 构建完整 URL（使用 PAN_DOMAIN，不是 baseURL）
	reqURL := PAN_DOMAIN + USER_INFO

	// 解析 URL 并添加查询参数
	parsedURL, err := url.Parse(reqURL)
	if err != nil {
		return &StandardResponse{
			Success: false,
			Code:    "URL_PARSE_ERROR",
			Message: fmt.Sprintf("failed to parse URL: %v", err),
			Data:    nil,
		}, nil
	}

	// 添加查询参数
	query := parsedURL.Query()
	query.Set("fr", "pc")
	query.Set("platform", "pc")
	parsedURL.RawQuery = query.Encode()
	reqURL = parsedURL.String()

	// 使用 makeRequest 发起请求，跳过认证检查（避免死锁，因为 checkAuth 会调用 GetUserInfo）
	jsonResp, err := qc.makeRequest("GET", reqURL, nil, nil, true)

	if err != nil {
		return &StandardResponse{
			Success: false,
			Code:    "REQUEST_ERROR",
			Message: fmt.Sprintf("request failed: %v", err),
			Data:    nil,
		}, nil
	}

	// 检查 success 字段
	success, ok := jsonResp["success"].(bool)
	message, msgOk := jsonResp["msg"].(string)
	code, _ := jsonResp["code"].(string)

	// 检查 data 字段是否存在且有效
	data, dataOk := jsonResp["data"].(map[string]interface{})

	// 如果 success 字段明确为 false，或者 data 不存在/为空，则认为是失败
	if (ok && !success) || !dataOk || data == nil || len(data) == 0 {
		errMsg := "登录失败，请检查 Token 是否正确"
		if msgOk && message != "" {
			errMsg = message
		}
		return &StandardResponse{
			Success: false,
			Code:    code,
			Message: errMsg,
		}, nil
	}

	return &StandardResponse{
		Success: true,
		Code:    code,
		Message: "get user info success",
		Data:    data,
	}, nil
}
