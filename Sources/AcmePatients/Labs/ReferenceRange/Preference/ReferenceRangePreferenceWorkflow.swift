import AcmePlatform
import Foundation

extension Labs {
    /// Moves reference range preferences through their life cycle and keeps a journal of what it did.
    final class ReferenceRangePreferenceDesk {
        var store: any ReferenceRangePreferenceStore
        var validator: ReferenceRangePreferenceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ReferenceRangePreferenceEngine

        init(store: any ReferenceRangePreferenceStore, validator: ReferenceRangePreferenceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ReferenceRangePreferenceEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("reference range preference \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ReferenceRangePreferenceStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("reference range preference \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ReferenceRangePreferenceStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("reference range preference \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newReferenceRangePreferenceDesk(_ store: any ReferenceRangePreferenceStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ReferenceRangePreferenceDesk {
        return ReferenceRangePreferenceDesk(
            store: store,
            validator: defaultReferenceRangePreferenceValidator(),
            clock: clock,
            journal: [],
            engine: defaultReferenceRangePreferenceEngine(flags)
        )
    }
}
