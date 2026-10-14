@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryProgramGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ProgramGroupStore = CareManagement.newMemoryProgramGroupStore()
        let item = CareManagement.newProgramGroup("code-665", label: "label-436")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
