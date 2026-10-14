import AcmePlatform
import Foundation

extension Imaging {
    /// Moves modality baselines through their life cycle and keeps a journal of what it did.
    final class ModalityBaselineManager {
        var store: any ModalityBaselineStore
        var validator: ModalityBaselineValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ModalityBaselineEngine

        init(store: any ModalityBaselineStore, validator: ModalityBaselineValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ModalityBaselineEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("modality baseline \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ModalityBaselineStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("modality baseline \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ModalityBaselineStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("modality baseline \(code) not found")
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
                if item.createdAt > cutoff {
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

    static func newModalityBaselineManager(_ store: any ModalityBaselineStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ModalityBaselineManager {
        return ModalityBaselineManager(
            store: store,
            validator: defaultModalityBaselineValidator(),
            clock: clock,
            journal: [],
            engine: defaultModalityBaselineEngine(flags)
        )
    }
}
