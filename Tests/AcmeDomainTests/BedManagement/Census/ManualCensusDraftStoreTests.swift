@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryManualCensusDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.ManualCensusDraftStore = BedManagement.newMemoryManualCensusDraftStore()
        let item = BedManagement.newManualCensusDraft("code-948", label: "label-111")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
