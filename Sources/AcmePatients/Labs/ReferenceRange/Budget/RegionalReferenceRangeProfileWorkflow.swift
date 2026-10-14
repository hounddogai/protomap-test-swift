import AcmePlatform
import Foundation

extension Labs {
    /// Moves regional reference range profiles through their life cycle and keeps a journal of what it did.
    final class RegionalReferenceRangeProfileService {
        var store: any RegionalReferenceRangeProfileStore
        var validator: RegionalReferenceRangeProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RegionalReferenceRangeProfileStore, validator: RegionalReferenceRangeProfileValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional reference range profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalReferenceRangeProfileStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional reference range profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalReferenceRangeProfileStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
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

    static func newRegionalReferenceRangeProfileService(_ store: any RegionalReferenceRangeProfileStore, clock: any Kit.Clocks.Clock) -> RegionalReferenceRangeProfileService {
        return RegionalReferenceRangeProfileService(
            store: store,
            validator: defaultRegionalReferenceRangeProfileValidator(),
            clock: clock,
            journal: []
        )
    }
}
