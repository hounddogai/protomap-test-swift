import AcmePlatform
import Foundation

extension Labs {
    /// Moves panel overrides through their life cycle and keeps a journal of what it did.
    final class PanelOverrideManager {
        var store: any PanelOverrideStore
        var validator: PanelOverrideValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PanelOverrideEngine

        init(store: any PanelOverrideStore, validator: PanelOverrideValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PanelOverrideEngine) {
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
                throw Kit.Failure("panel override \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PanelOverrideStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("panel override \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PanelOverrideStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("panel override \(code) not found")
            }
            let result = engine.run(item)
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

    static func newPanelOverrideManager(_ store: any PanelOverrideStore, clock: any Kit.Clocks.Clock) -> PanelOverrideManager {
        return PanelOverrideManager(
            store: store,
            validator: defaultPanelOverrideValidator(),
            clock: clock,
            journal: [],
            engine: defaultPanelOverrideEngine()
        )
    }
}
