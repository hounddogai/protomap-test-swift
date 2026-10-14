import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves tiered isolation templates through their life cycle and keeps a journal of what it did.
    final class TieredIsolationTemplateCoordinator {
        var store: any TieredIsolationTemplateStore
        var validator: TieredIsolationTemplateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredIsolationTemplateEngine

        init(store: any TieredIsolationTemplateStore, validator: TieredIsolationTemplateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredIsolationTemplateEngine) {
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
                throw Kit.Failure("tiered isolation template \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredIsolationTemplateStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered isolation template \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredIsolationTemplateStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered isolation template \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newTieredIsolationTemplateCoordinator(_ store: any TieredIsolationTemplateStore, clock: any Kit.Clocks.Clock) -> TieredIsolationTemplateCoordinator {
        return TieredIsolationTemplateCoordinator(
            store: store,
            validator: defaultTieredIsolationTemplateValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredIsolationTemplateEngine()
        )
    }
}
