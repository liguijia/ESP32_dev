#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include "WirelessID_config.h"

static const char *TAG = WIRELESSID_LOG_TAG;

static void log_startup_banner(void)
{
    ESP_LOGI(TAG, "%s", WIRELESSID_STARTUP_BANNER);
    ESP_LOGI(TAG, "Template ready: update main/WirelessID.c and main/include/WirelessID_config.h for your project");
    ESP_LOGI(TAG, "Heartbeat interval: %d ms", WIRELESSID_HEARTBEAT_INTERVAL_MS);
}

static void log_heartbeat(uint32_t heartbeat_count)
{
    ESP_LOGI(
        TAG,
        "app=%s heartbeat=%lu uptime_ms=%lu",
        WIRELESSID_APP_NAME,
        (unsigned long)heartbeat_count,
        (unsigned long)(xTaskGetTickCount() * portTICK_PERIOD_MS));
}

void app_main(void)
{
    uint32_t heartbeat_count = 0;

    log_startup_banner();

    while (1) {
        log_heartbeat(heartbeat_count);
        heartbeat_count++;
        vTaskDelay(pdMS_TO_TICKS(WIRELESSID_HEARTBEAT_INTERVAL_MS));
    }
}
