import AcmePlatform
import Foundation

extension Imaging {
    /// Moves manual modality entries through their life cycle and keeps a journal of what it did.
    final class ManualModalityEntryService {
        var store: any ManualModalityEntryStore
        var validator: ManualModalityEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ManualModalityEntryEngine

        init(store: any ManualModalityEntryStore, validator: ManualModalityEntryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ManualModalityEntryEngine) {
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
                throw Kit.Failure("manual modality entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualModalityEntryStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual modality entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualModalityEntryStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual modality entry \(code) not found")
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
                if item.startsAt > cutoff {
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

    static func newManualModalityEntryService(_ store: any ManualModalityEntryStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ManualModalityEntryService {
        return ManualModalityEntryService(
            store: store,
            validator: defaultManualModalityEntryValidator(),
            clock: clock,
            journal: [],
            engine: defaultManualModalityEntryEngine(flags)
        )
    }
}
