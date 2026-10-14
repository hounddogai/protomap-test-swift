@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryCappedChargeAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.CappedChargeAssignmentStore = RevenueCycle.newMemoryCappedChargeAssignmentStore()
        let item = RevenueCycle.newCappedChargeAssignment("code-274", label: "label-121")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
