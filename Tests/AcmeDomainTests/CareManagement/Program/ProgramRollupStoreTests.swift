@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryProgramRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ProgramRollupStore = CareManagement.newMemoryProgramRollupStore()
        let item = CareManagement.newProgramRollup("code-321", label: "label-879")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
