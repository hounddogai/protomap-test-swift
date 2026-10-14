@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryProgramTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ProgramTemplateStore = CareManagement.newMemoryProgramTemplateStore()
        let item = CareManagement.newProgramTemplate("code-251", name: "name-239")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
