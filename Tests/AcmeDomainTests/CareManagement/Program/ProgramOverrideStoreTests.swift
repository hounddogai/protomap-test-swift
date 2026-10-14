@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryProgramOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ProgramOverrideStore = CareManagement.newMemoryProgramOverrideStore()
        let item = CareManagement.newProgramOverride("code-82", name: "name-271")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
