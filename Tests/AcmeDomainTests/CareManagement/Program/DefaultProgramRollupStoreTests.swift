@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryDefaultProgramRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.DefaultProgramRollupStore = CareManagement.newMemoryDefaultProgramRollupStore()
        let item = CareManagement.newDefaultProgramRollup("code-721", label: "label-930")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
