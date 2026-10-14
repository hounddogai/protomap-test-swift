@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryDefaultProgramBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.DefaultProgramBaselineStore = CareManagement.newMemoryDefaultProgramBaselineStore()
        let item = CareManagement.newDefaultProgramBaseline("code-883", label: "label-405")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
