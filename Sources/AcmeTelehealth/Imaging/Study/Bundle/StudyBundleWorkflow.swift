import AcmePlatform
import Foundation

extension Imaging {
    /// Moves study bundles through their life cycle and keeps a journal of what it did.
    final class StudyBundleDesk {
        var store: any StudyBundleStore
        var validator: StudyBundleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any StudyBundleStore, validator: StudyBundleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("study bundle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StudyBundleStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("study bundle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StudyBundleStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                let problems = validator.validate(item)
                if problems.count == 0 {
                    continue
                }
                self.note("\(item.code) needs attention: \(problems.joined(separator: ", "))")
                changed += 1
            }
            return changed
        }
    }

    static func newStudyBundleDesk(_ store: any StudyBundleStore, clock: any Kit.Clocks.Clock) -> StudyBundleDesk {
        return StudyBundleDesk(store: store, validator: defaultStudyBundleValidator(), clock: clock, journal: [])
    }
}
