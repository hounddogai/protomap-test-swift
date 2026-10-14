import AcmePlatform
import Foundation

extension Imaging {
    /// Moves primary modality targets through their life cycle and keeps a journal of what it did.
    final class PrimaryModalityTargetManager {
        var store: any PrimaryModalityTargetStore
        var validator: PrimaryModalityTargetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryModalityTargetEngine

        init(store: any PrimaryModalityTargetStore, validator: PrimaryModalityTargetValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryModalityTargetEngine) {
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
                throw Kit.Failure("primary modality target \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryModalityTargetStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary modality target \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryModalityTargetStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary modality target \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newPrimaryModalityTargetManager(_ store: any PrimaryModalityTargetStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PrimaryModalityTargetManager {
        return PrimaryModalityTargetManager(
            store: store,
            validator: defaultPrimaryModalityTargetValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryModalityTargetEngine(flags)
        )
    }
}
