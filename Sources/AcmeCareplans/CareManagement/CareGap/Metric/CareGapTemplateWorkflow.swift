import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves care gap templates through their life cycle and keeps a journal of what it did.
    final class CareGapTemplateCoordinator {
        var store: any CareGapTemplateStore
        var validator: CareGapTemplateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CareGapTemplateEngine

        init(store: any CareGapTemplateStore, validator: CareGapTemplateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CareGapTemplateEngine) {
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
                throw Kit.Failure("care gap template \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CareGapTemplateStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care gap template \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CareGapTemplateStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("care gap template \(code) not found")
            }
            let result = engine.run(item)
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

    static func newCareGapTemplateCoordinator(_ store: any CareGapTemplateStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CareGapTemplateCoordinator {
        return CareGapTemplateCoordinator(
            store: store,
            validator: defaultCareGapTemplateValidator(),
            clock: clock,
            journal: [],
            engine: defaultCareGapTemplateEngine(flags)
        )
    }
}
