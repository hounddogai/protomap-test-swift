import AcmePlatform
import Foundation

extension Labs {
    /// Moves adaptive panel estimates through their life cycle and keeps a journal of what it did.
    final class AdaptivePanelEstimateManager {
        var store: any AdaptivePanelEstimateStore
        var validator: AdaptivePanelEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AdaptivePanelEstimateStore, validator: AdaptivePanelEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive panel estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptivePanelEstimateStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive panel estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptivePanelEstimateStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
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

    static func newAdaptivePanelEstimateManager(_ store: any AdaptivePanelEstimateStore, clock: any Kit.Clocks.Clock) -> AdaptivePanelEstimateManager {
        return AdaptivePanelEstimateManager(
            store: store,
            validator: defaultAdaptivePanelEstimateValidator(),
            clock: clock,
            journal: []
        )
    }
}
