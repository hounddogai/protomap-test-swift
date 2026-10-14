@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryManualProgramOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ManualProgramOverrideStore = CareManagement.newMemoryManualProgramOverrideStore()
        let item = CareManagement.newManualProgramOverride("code-602", name: "name-260")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
