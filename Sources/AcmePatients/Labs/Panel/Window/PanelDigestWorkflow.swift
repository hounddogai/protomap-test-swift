import AcmePlatform
import Foundation

extension Labs {
    /// Moves panel digests through their life cycle and keeps a journal of what it did.
    final class PanelDigestCoordinator {
        var store: any PanelDigestStore
        var validator: PanelDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PanelDigestEngine

        init(store: any PanelDigestStore, validator: PanelDigestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PanelDigestEngine) {
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
                throw Kit.Failure("panel digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PanelDigestStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("panel digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PanelDigestStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("panel digest \(code) not found")
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

    static func newPanelDigestCoordinator(_ store: any PanelDigestStore, clock: any Kit.Clocks.Clock) -> PanelDigestCoordinator {
        return PanelDigestCoordinator(
            store: store,
            validator: defaultPanelDigestValidator(),
            clock: clock,
            journal: [],
            engine: defaultPanelDigestEngine()
        )
    }
}
