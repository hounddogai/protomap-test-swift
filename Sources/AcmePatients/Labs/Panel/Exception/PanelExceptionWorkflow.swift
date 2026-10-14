import AcmePlatform
import Foundation

extension Labs {
    /// Moves panel exceptions through their life cycle and keeps a journal of what it did.
    final class PanelExceptionWorkflow {
        var store: any PanelExceptionStore
        var validator: PanelExceptionValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PanelExceptionEngine

        init(store: any PanelExceptionStore, validator: PanelExceptionValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PanelExceptionEngine) {
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
                throw Kit.Failure("panel exception \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PanelExceptionStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("panel exception \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PanelExceptionStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("panel exception \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newPanelExceptionWorkflow(_ store: any PanelExceptionStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PanelExceptionWorkflow {
        return PanelExceptionWorkflow(
            store: store,
            validator: defaultPanelExceptionValidator(),
            clock: clock,
            journal: [],
            engine: defaultPanelExceptionEngine(flags)
        )
    }
}
