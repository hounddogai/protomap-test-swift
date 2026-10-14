import AcmePlatform
import Foundation

extension Labs {
    /// Moves specimen reviews through their life cycle and keeps a journal of what it did.
    final class SpecimenReviewDesk {
        var store: any SpecimenReviewStore
        var validator: SpecimenReviewValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any SpecimenReviewStore, validator: SpecimenReviewValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("specimen review \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SpecimenReviewStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("specimen review \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SpecimenReviewStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newSpecimenReviewDesk(_ store: any SpecimenReviewStore, clock: any Kit.Clocks.Clock) -> SpecimenReviewDesk {
        return SpecimenReviewDesk(
            store: store,
            validator: defaultSpecimenReviewValidator(),
            clock: clock,
            journal: []
        )
    }
}
