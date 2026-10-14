@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryStudyLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.StudyLedgerStore = Imaging.newMemoryStudyLedgerStore()
        let item = Imaging.newStudyLedger("code-2", label: "label-972")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
