@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryStrictAssessmentEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.StrictAssessmentEntryStore = CareManagement.newMemoryStrictAssessmentEntryStore()
        let item = CareManagement.newStrictAssessmentEntry("code-643", label: "label-14")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
