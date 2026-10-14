@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRollingStatementPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RollingStatementPreferenceStore = RevenueCycle.newMemoryRollingStatementPreferenceStore()
        let item = RevenueCycle.newRollingStatementPreference("code-102", label: "label-148")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
