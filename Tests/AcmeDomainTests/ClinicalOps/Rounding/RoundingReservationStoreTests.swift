@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRoundingReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RoundingReservationStore = ClinicalOps.newMemoryRoundingReservationStore()
        let item = ClinicalOps.newRoundingReservation("code-675", name: "name-399")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
