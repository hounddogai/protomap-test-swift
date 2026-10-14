@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryDefaultAssessmentEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.DefaultAssessmentEntryStore = CareManagement.newMemoryDefaultAssessmentEntryStore()
        let item = CareManagement.newDefaultAssessmentEntry("code-606", name: "name-730")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
