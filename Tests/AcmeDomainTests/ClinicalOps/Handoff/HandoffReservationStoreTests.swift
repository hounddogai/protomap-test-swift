@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryHandoffReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.HandoffReservationStore = ClinicalOps.newMemoryHandoffReservationStore()
        let item = ClinicalOps.newHandoffReservation("code-473", title: "title-614")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
