@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryDenialScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.DenialScoreStore = RevenueCycle.newMemoryDenialScoreStore()
        let item = RevenueCycle.newDenialScore("code-738", label: "label-943")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
