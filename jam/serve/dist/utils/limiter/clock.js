export function getMilliseconds() {
    return Date.now();
}
export function wait(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}
//# sourceMappingURL=clock.js.map