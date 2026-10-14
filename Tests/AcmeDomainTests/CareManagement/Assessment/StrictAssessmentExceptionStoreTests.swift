@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryStrictAssessmentExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.StrictAssessmentExceptionStore = CareManagement.newMemoryStrictAssessmentExceptionStore()
        let item = CareManagement.newStrictAssessmentException("code-179", label: "label-872")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
