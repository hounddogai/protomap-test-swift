@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryGlobalRemittanceAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.GlobalRemittanceAssignmentStore = RevenueCycle.newMemoryGlobalRemittanceAssignmentStore()
        let item = RevenueCycle.newGlobalRemittanceAssignment("code-9", label: "label-27")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
