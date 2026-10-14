import AcmePlatform
import Foundation

extension Labs {
    /// Moves panel assignments through their life cycle and keeps a journal of what it did.
    final class PanelAssignmentCoordinator {
        var store: any PanelAssignmentStore
        var validator: PanelAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PanelAssignmentEngine

        init(store: any PanelAssignmentStore, validator: PanelAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PanelAssignmentEngine) {
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
                throw Kit.Failure("panel assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PanelAssignmentStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("panel assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PanelAssignmentStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("panel assignment \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newPanelAssignmentCoordinator(_ store: any PanelAssignmentStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PanelAssignmentCoordinator {
        return PanelAssignmentCoordinator(
            store: store,
            validator: defaultPanelAssignmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultPanelAssignmentEngine(flags)
        )
    }
}
