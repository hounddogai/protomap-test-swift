@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryDisclosureAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.DisclosureAssignmentStore = Consent.newMemoryDisclosureAssignmentStore()
        let item = Consent.newDisclosureAssignment("code-120", label: "label-278")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
