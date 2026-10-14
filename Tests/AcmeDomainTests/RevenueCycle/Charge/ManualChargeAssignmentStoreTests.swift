@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryManualChargeAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ManualChargeAssignmentStore = RevenueCycle.newMemoryManualChargeAssignmentStore()
        let item = RevenueCycle.newManualChargeAssignment("code-632", name: "name-309")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
