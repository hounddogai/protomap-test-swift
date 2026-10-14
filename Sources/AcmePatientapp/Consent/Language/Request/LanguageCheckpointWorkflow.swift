import AcmePlatform
import Foundation

extension Consent {
    /// Moves language checkpoints through their life cycle and keeps a journal of what it did.
    final class LanguageCheckpointService {
        var store: any LanguageCheckpointStore
        var validator: LanguageCheckpointValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LanguageCheckpointEngine

        init(store: any LanguageCheckpointStore, validator: LanguageCheckpointValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LanguageCheckpointEngine) {
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
                throw Kit.Failure("language checkpoint \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LanguageCheckpointStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("language checkpoint \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LanguageCheckpointStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("language checkpoint \(code) not found")
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

    static func newLanguageCheckpointService(_ store: any LanguageCheckpointStore, clock: any Kit.Clocks.Clock) -> LanguageCheckpointService {
        return LanguageCheckpointService(
            store: store,
            validator: defaultLanguageCheckpointValidator(),
            clock: clock,
            journal: [],
            engine: defaultLanguageCheckpointEngine()
        )
    }
}
