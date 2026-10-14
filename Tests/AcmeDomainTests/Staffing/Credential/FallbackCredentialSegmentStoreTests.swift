@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryFallbackCredentialSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.FallbackCredentialSegmentStore = Staffing.newMemoryFallbackCredentialSegmentStore()
        let item = Staffing.newFallbackCredentialSegment("code-132", title: "title-169")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
