@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRollingRemittanceAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RollingRemittanceAssignmentStore = RevenueCycle.newMemoryRollingRemittanceAssignmentStore()
        let item = RevenueCycle.newRollingRemittanceAssignment("code-598", name: "name-310")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
