import AcmePlatform
import Foundation
import Testing

@Suite struct KitRetryTests {
    @Test func stopsAtTheFirstSuccess() throws {
        let policy = Kit.Retry.Policy(attempts: 4, backoff: Kit.Retry.ConstantBackoff(millis: 10))
        let used = try policy.run({ (attempt: Int) -> Bool in return attempt == 2 })
        #expect(used == 3)
        #expect(policy.totalDelay() == 40)
    }
}
