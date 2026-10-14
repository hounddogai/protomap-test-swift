@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryPendingProgramTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.PendingProgramTargetStore = CareManagement.newMemoryPendingProgramTargetStore()
        let item = CareManagement.newPendingProgramTarget("code-579", name: "name-661")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
