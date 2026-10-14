@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryPendingStatementAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.PendingStatementAgreementStore = RevenueCycle.newMemoryPendingStatementAgreementStore()
        let item = RevenueCycle.newPendingStatementAgreement("code-382", name: "name-884")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
