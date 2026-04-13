const MINUTES_PER_HOUR = 60;

function resolveDelayMinutes(model) {
  const noticeDelayMinutes = Number(model?.guest_comment_delay_notice?.delay_minutes);

  if (Number.isFinite(noticeDelayMinutes) && noticeDelayMinutes > 0) {
    return noticeDelayMinutes;
  }

  const stateDelayMinutes = Number(model?.guest_comment_delay_state?.delay_minutes);

  if (Number.isFinite(stateDelayMinutes) && stateDelayMinutes > 0) {
    return stateDelayMinutes;
  }

  return null;
}

function formatDelayDurationZh(minutes) {
  if (!Number.isFinite(minutes) || minutes <= 0) {
    return "几分钟";
  }

  if (minutes % MINUTES_PER_HOUR === 0) {
    return `${minutes / MINUTES_PER_HOUR} 小时`;
  }

  return `${minutes} 分钟`;
}

function buildGuestNoticeZh(model) {
  const delayDuration = formatDelayDurationZh(resolveDelayMinutes(model));

  return `部分最新评论对游客暂时不可见，将在约 ${delayDuration} 后可见；登录后可立即查看。`;
}

<template>
  {{#if @model.guest_comment_delay_notice}}
    <div class="guest-comment-delay-notice alert alert-info">
      {{buildGuestNoticeZh @model}}
    </div>
  {{/if}}
</template>
