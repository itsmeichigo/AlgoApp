//
//  DetailViewModel.swift
//  AlgoApp
//
//  Created by Huong Do on 2/4/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import Foundation

protocol DetailViewModelType {
    
}

final class DetailViewModel: DetailViewModelType {
    
    let detail: QuestionDetailModel
    
    init(detail: QuestionDetailModel) {
        self.detail = detail
    }
}
