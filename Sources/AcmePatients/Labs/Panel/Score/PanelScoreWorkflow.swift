import AcmePlatform
import Foundation

extension Labs {
    /// Moves panel scores through their life cycle and keeps a journal of what it did.
    final class PanelScoreCoordinator {
        var store: any PanelScoreStore
        var validator: PanelScoreValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PanelScoreStore, validator: PanelScoreValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("panel score \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PanelScoreStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("panel score \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PanelScoreStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newPanelScoreCoordinator(_ store: any PanelScoreStore, clock: any Kit.Clocks.Clock) -> PanelScoreCoordinator {
        return PanelScoreCoordinator(
            store: store,
            validator: defaultPanelScoreValidator(),
            clock: clock,
            journal: []
        )
    }
}
