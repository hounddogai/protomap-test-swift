@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemorySeasonalStatementAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.SeasonalStatementAgreementStore = RevenueCycle.newMemorySeasonalStatementAgreementStore()
        let item = RevenueCycle.newSeasonalStatementAgreement("code-866", name: "name-728")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
