@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryStudyProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.StudyProposalStore = Imaging.newMemoryStudyProposalStore()
        let item = Imaging.newStudyProposal("code-944", title: "title-120")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
