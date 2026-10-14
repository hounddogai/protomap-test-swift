import AcmePlatform
import Foundation

extension Imaging {
    /// Moves capped modality preferences through their life cycle and keeps a journal of what it did.
    final class CappedModalityPreferenceService {
        var store: any CappedModalityPreferenceStore
        var validator: CappedModalityPreferenceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedModalityPreferenceEngine

        init(store: any CappedModalityPreferenceStore, validator: CappedModalityPreferenceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedModalityPreferenceEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped modality preference \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedModalityPreferenceStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped modality preference \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedModalityPreferenceStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped modality preference \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newCappedModalityPreferenceService(_ store: any CappedModalityPreferenceStore, clock: any Kit.Clocks.Clock) -> CappedModalityPreferenceService {
        return CappedModalityPreferenceService(
            store: store,
            validator: defaultCappedModalityPreferenceValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedModalityPreferenceEngine()
        )
    }
}
