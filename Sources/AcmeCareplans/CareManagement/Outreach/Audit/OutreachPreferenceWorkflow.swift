import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves outreach preferences through their life cycle and keeps a journal of what it did.
    final class OutreachPreferenceWorkflow {
        var store: any OutreachPreferenceStore
        var validator: OutreachPreferenceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: OutreachPreferenceEngine

        init(store: any OutreachPreferenceStore, validator: OutreachPreferenceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: OutreachPreferenceEngine) {
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
                throw Kit.Failure("outreach preference \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(OutreachPreferenceStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("outreach preference \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(OutreachPreferenceStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("outreach preference \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newOutreachPreferenceWorkflow(_ store: any OutreachPreferenceStore, clock: any Kit.Clocks.Clock) -> OutreachPreferenceWorkflow {
        return OutreachPreferenceWorkflow(
            store: store,
            validator: defaultOutreachPreferenceValidator(),
            clock: clock,
            journal: [],
            engine: defaultOutreachPreferenceEngine()
        )
    }
}
