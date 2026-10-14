@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryAssessmentRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.AssessmentRecordStore = CareManagement.newMemoryAssessmentRecordStore()
        let item = CareManagement.newAssessmentRecord("code-754", title: "title-309")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
