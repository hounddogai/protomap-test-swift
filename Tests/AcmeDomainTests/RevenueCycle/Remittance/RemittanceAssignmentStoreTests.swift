@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRemittanceAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RemittanceAssignmentStore = RevenueCycle.newMemoryRemittanceAssignmentStore()
        let item = RevenueCycle.newRemittanceAssignment("code-486", name: "name-21")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
