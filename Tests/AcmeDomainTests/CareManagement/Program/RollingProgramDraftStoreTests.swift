@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryRollingProgramDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.RollingProgramDraftStore = CareManagement.newMemoryRollingProgramDraftStore()
        let item = CareManagement.newRollingProgramDraft("code-199", name: "name-825")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
