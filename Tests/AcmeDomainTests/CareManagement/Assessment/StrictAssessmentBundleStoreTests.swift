@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryStrictAssessmentBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.StrictAssessmentBundleStore = CareManagement.newMemoryStrictAssessmentBundleStore()
        let item = CareManagement.newStrictAssessmentBundle("code-122", label: "label-246")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
