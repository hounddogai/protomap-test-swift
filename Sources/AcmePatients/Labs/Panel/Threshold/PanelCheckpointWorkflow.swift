import AcmePlatform
import Foundation

extension Labs {
    /// Moves panel checkpoints through their life cycle and keeps a journal of what it did.
    final class PanelCheckpointDesk {
        var store: any PanelCheckpointStore
        var validator: PanelCheckpointValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PanelCheckpointEngine

        init(store: any PanelCheckpointStore, validator: PanelCheckpointValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PanelCheckpointEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("panel checkpoint \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PanelCheckpointStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("panel checkpoint \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PanelCheckpointStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("panel checkpoint \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newPanelCheckpointDesk(_ store: any PanelCheckpointStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PanelCheckpointDesk {
        return PanelCheckpointDesk(
            store: store,
            validator: defaultPanelCheckpointValidator(),
            clock: clock,
            journal: [],
            engine: defaultPanelCheckpointEngine(flags)
        )
    }
}
